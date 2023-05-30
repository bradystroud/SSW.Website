import classNames from "classnames";
import { ErrorMessage, Field, FieldHookConfig, useField } from "formik";
import {
  ChangeEvent,
  ChangeEventHandler,
  FC
} from "react";
import { FormGroupProps } from "./formGroupTypes";
import styles from "./formGroup.module.css";

const FormGroupSelect: FC<
  FieldHookConfig<string> &
    FormGroupProps<HTMLSelectElement>
> = ({
  label,
  activeLabelClass,
  fieldClass,
  errorMessageClass,
  handleChange,
  handleClick,
  ...props
}) => {
  const [field, meta] = useField(props);
  
  !errorMessageClass && (errorMessageClass = styles["invalid-feedback"]);

  return (
      <div className={styles["field-wrapper"]}>
      <label htmlFor={props.id || props.name} className={styles[activeLabelClass]}>
        {label}
      </label>
      <Field name={field.name}>
        {({ field }) => {
          const selectOnChange: ChangeEventHandler<HTMLSelectElement> = (
            e: ChangeEvent<HTMLSelectElement>
          ) => {
            field.onChange(e);
            !!handleChange && handleChange(field, e);
          };

          return (
            <select
              {...field}
              {...props}
              className={classNames(fieldClass || styles["form-select"],
                !!meta.error && styles["is-invalid"],
              )}
              onChange={selectOnChange}
              onClick={handleClick}
            >
              {props.children}
            </select>
          );
        }}
      </Field>
      <ErrorMessage
        name={props.name}
        className={classNames(styles["invalid-feedback"], errorMessageClass)}
        component="div"
      />
    </div>
  );
};

export default FormGroupSelect;
